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
  { schedule: "*/5 * * * *", timeZone: TZ },
  async () => {
    try {
      const now = moment().tz(TZ);
      const hora = now.hour(), min = now.minute();

      // 1) Solo después de las 18:10
      if (hora < 18 || (hora === 18 && min < 10)) {
        logger.info("Antes de las 18:10 → no se actualiza.");
        return;
      }

      const db    = admin.firestore();
      const colR  = db.collection("reservaciones");
      const toUpdate = new Set<string>();

      // 2) Solo si hoy hubo cancelaciones
      const inicioHoy = admin.firestore.Timestamp.
      fromDate(now.clone().startOf("day").toDate());
      const finHoy    = admin.firestore.Timestamp.
      fromDate(now.clone().endOf("day").toDate());
      const canceladas = await colR
        .where("fechaInicio", ">=", inicioHoy)
        .where("fechaInicio", "<=", finHoy)
        .where("estado", "==", "cancelado")
        .get();

      if (canceladas.empty) {
        logger.info("No hubo cancelaciones hoy → nada que hacer.");
        return;
      }
      logger.info("Cancelaciones hoy → recalculando disponibilidad.");

      // 3) Traer todas las reservas FUTURAS pendientes/confirmadas
      const futuras = await colR
        .where("fechaInicio", ">", admin.firestore.
          Timestamp.fromDate(now.toDate()))
        .where("estado", "in", ["pendiente", "confirmado"])
        .get();

      if (futuras.empty) {
        logger.info("No hay reservaciones futuras.");
        return;
      }

      // 4) Extraer ID de cada espacio afectado
      futuras.docs.forEach(doc => {
        const data    = doc.data();
        let ruta = data.espacio as string;  // p.ej. "/espacios/A_1"
        if (typeof ruta !== "string") {
          logger.warn(`Reserva ${doc.id} sin campo 'espacio' válido`);
          return;
        }
        ruta = ruta.replace(/^\/+/, "");     // "espacios/A_1"
        const [col, id] = ruta.split("/");
        if (col !== "espacios" || !id) {
          logger.warn(`Reserva ${doc.id} ruta inesperada: ${data.espacio}`);
          return;
        }
        toUpdate.add(id);
      });

      // 5) Para cada espacio, si está libre y tiene reserva futura → marcar false
      const batch = db.batch();
      const finDeHoy = admin.firestore.Timestamp.
      fromDate(now.clone().endOf("day").toDate());

      for (const idEsp of toUpdate) {
        const eRef     = db.collection("espacios").doc(idEsp);
        const eSnap    = await eRef.get();
        if (!eSnap.exists) {
          logger.warn(`Espacio ${idEsp} no existe.`);
          continue;
        }
        const disponible = eSnap.get("disponible");
        if (disponible === true) {
          const futParaEsp = await colR
            .where("espacio", "==", `/espacios/${idEsp}`)
            .where("fechaInicio", ">", finDeHoy)
            .where("estado", "in", ["pendiente", "confirmado"])
            .limit(1)
            .get();

          if (!futParaEsp.empty) {
            batch.update(eRef, { disponible: false });
          }
        }
      }

      // 6) Aplicar todas las actualizaciones de golpe
      await batch.commit();
      logger.info("✅ Disponibilidad en colección 'espacios' actualizada.");

    } catch (err) {
      logger.error("❌ Error en actualizarDisponibilidadEspacios:", err);
    }
  }
);