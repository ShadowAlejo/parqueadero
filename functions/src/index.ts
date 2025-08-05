/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// functions/src/index.ts

import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import moment from "moment-timezone";

admin.initializeApp();
const TZ = "America/Guayaquil";

export const finalizarReservaciones = onSchedule(
  {schedule: "*/10 * * * *", timeZone: TZ},
  async () => {
    try {
      const now = moment().tz(TZ);
      const start = now.clone().startOf("day");
      const end = now.clone().endOf("day");
      const db = admin.firestore();
      const res = db.collection("reservaciones");
      const impact = new Set<string>();

      const tsStart = admin.firestore.Timestamp
        .fromDate(start.toDate());
      const tsEnd = admin.firestore.Timestamp
        .fromDate(end.toDate());

      // 1) Reservas de HOY pendientes/confirmadas
      const snap = await res
        .where("fechaInicio", ">=", tsStart)
        .where("fechaInicio", "<=", tsEnd)
        .where("estado", "in", ["pendiente", "confirmado"])
        .get();

      // 2) Finalizar si horaActual ≥ horaFin o ≥ 18
      const batchR = db.batch();
      snap.docs.forEach((doc) => {
        const data = doc.data();
        const finTs = data.fechaFin as admin.
        firestore.Timestamp;
        const finM = moment(finTs.toDate()).tz(TZ);

        const horaAct = now.hour();
        const horaFin = finM.hour();

        if (horaAct >= horaFin || horaAct >= 18) {
          batchR.update(doc.ref, {estado: "finalizado"});

          // Recoger referencia al espacio
          const refA = doc.get("espacioRef") as admin.
          firestore.DocumentReference;
          const refB = doc.get("espacio") as admin.
          firestore.DocumentReference;
          const spRef = refA ?? refB;

          if (spRef?.path) {
            impact.add(spRef.path);
          } else {
            logger.warn(
              `Reserva ${doc.id} sin espacioRef válido`
            );
          }
        }
      });
      await batchR.commit();

      // 3) Actualizar disponibilidad de espacios
      const batchE = db.batch();
      for (const path of impact) {
        const eRef = db.doc(path);

        // 3.1) ¿Reservas activas HOY?
        const hoy = await res
          .where("espacioRef", "==", eRef)
          .where("fechaInicio", ">=", tsStart)
          .where("fechaInicio", "<=", tsEnd)
          .where("estado", "in", ["pendiente", "confirmado"])
          .limit(1)
          .get();

        if (!hoy.empty) {
          batchE.update(eRef, {disponible: false});
          continue;
        }

        // 3.2) ¿Reservas futuras?
        const fut = await res
          .where("espacioRef", "==", eRef)
          .where("fechaInicio", ">", tsEnd)
          .where("estado", "in", ["pendiente", "confirmado"])
          .limit(1)
          .get();

        batchE.update(eRef, {disponible: fut.empty});
      }
      await batchE.commit();

      logger.info("📅 Finalización y actualización completadas");
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error("❌ Error en scheduler:", msg);
    }
  }
);

// Funcion para manejar el manejo de espacios disponibles con
// Reservaciones futuras
export const actualizarDisponibilidadEspacios = onSchedule(
  {schedule: "*/5 * * * *", timeZone: TZ},
  async () => {
    try {
      const now = moment().tz(TZ);
      const hora = now.hour(); const min = now.minute();

      // 1) Sólo después de 18:10
      if (hora < 18 || (hora === 18 && min < 10)) {
        logger.info("Antes de 18:10, no se actualiza.");
        return;
      }

      const db = admin.firestore();
      const colR = db.collection("reservaciones");
      const impact = new Set<string>();

      // 2) ¿Hay reservas CANCELADAS HOY?
      const inicioHoy = admin.firestore.
        Timestamp.fromDate(now.clone().startOf("day").toDate());
      const finHoy = admin.firestore.
        Timestamp.fromDate(now.clone().endOf("day").toDate());
      const canceladas = await colR
        .where("fechaInicio", ">=", inicioHoy)
        .where("fechaInicio", "<=", finHoy)
        .where("estado", "==", "cancelado")
        .get();

      if (canceladas.empty) {
        logger.info("Sin cancelaciones hoy"+
          " → nada que recalcular.");
        return;
      }
      logger.info("Se detectaron cancelaciones"+
        " hoy → recalculando espacios.");

      // 3) Consultar TODAS las reservas
      // FUTURAS pendientes/confirmadas
      const futuras = await colR
        .where("fechaInicio", ">", admin.firestore.
          Timestamp.fromDate(now.toDate()))
        .where("estado", "in", ["pendiente", "confirmado"])
        .get();

      if (futuras.empty) {
        logger.info("No hay reservaciones futuras.");
        return;
      }

      // 4) Extraer referencias a ESPACIO (docRef) de cada reserva
      futuras.docs.forEach((doc) => {
        const data = doc.data();
        const espField = data.espacio;
        let espRef: admin.
        firestore.DocumentReference | null = null;

        // Si fuera DocumentReference (no en tu caso):
        if (espField instanceof admin.
          firestore.DocumentReference) {
          espRef = espField;
        } else if (typeof espField === "string") {
          espRef = db.doc(espField);
        }

        if (espRef) {
          impact.add(espRef.path);
        } else {
          logger.warn(`Reserva ${doc.id} sin campo 'espacio' válido`);
        }
      });

      // 5) Para cada espacio en impact: si está disponible
      // y tiene reservas futuras → disponible=false
      const batch = db.batch();
      const finDeHoy = admin.firestore.Timestamp.
        fromDate(now.clone().endOf("day").toDate());

      for (const path of impact) {
        const eRef = db.doc(path);
        const eSnap = await eRef.get();
        const disponible = eSnap.get("disponible");

        if (disponible === true) {
          // Verificar si hay reserva FUTURA para este espacio
          const futEsp = await colR
            .where("espacio", "==", path)
            .where("fechaInicio", ">", finDeHoy)
            .where("estado", "in", ["pendiente", "confirmado"])
            .limit(1)
            .get();

          if (!futEsp.empty) {
            batch.update(eRef, {disponible: false});
          }
        }
      }

      // 6) Commit de actualizaciones
      await batch.commit();
      logger.info("✅ Disponibilidades actualizadas.");
    } catch (err) {
      logger.error("❌ Error en actualizarDisponibilidadEspacios:", err);
    }
  }
);
