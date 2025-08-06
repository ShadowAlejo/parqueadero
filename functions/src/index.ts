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
      const horaAct = now.hour();
      const start = now.clone().startOf("day");
      const end = now.clone().endOf("day");
      const db = admin.firestore();
      const res = db.collection("reservaciones");
      const impact = new Set<string>();

      // 1) Salir si aún no son las 6 AM
      if (horaAct < 6) {
        logger.info(`⏳ Aún no son las 6 AM (${horaAct}h). 
          Se omite la ejecución.`);
        return; // Detener la ejecución si es antes de las 6 AM
      }

      // 2) Salir si son mas de las 18:20
      if (horaAct > 18 ||horaAct === 18 && now.minute() > 15) {
        logger.info(`⏳ Paso a las 18:20 (${horaAct}h). 
          Se omite la ejecución.`);
        return; // Detener la ejecución si es antes de las 6 AM
      }

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
        const finTs = data.fechaFin as admin.firestore.Timestamp;
        const finM = moment(finTs.toDate()).tz(TZ);

        const horaAct = now.hour();
        const horaFin = finM.hour();

        // Solo procesar si la horaFin es anterior o igual a la hora actual
        if ((horaAct > horaFin) || (horaAct === horaFin &&
          now.minute() >= finM.minute()) || horaAct >= 18) {
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
            logger.warn(`Reserva ${doc.id} sin espacioRef válido`);
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

      // 1) Sólo después de las 18:20
      if (hora < 18 || (hora === 18 && min < 20)) {
        logger.info("Antes de 18:10 → no se actualiza.");
        return;
      }

      // 2) Para a las 23:50
      if (hora > 23 || (hora === 23 && min > 50)) {
        logger.info("Despues de 23:50 → no se actualiza.");
        return;
      }

      const db = admin.firestore();
      const colR = db.collection("reservaciones");
      const toUpdate = new Set<string>();

      // 2) Si hoy NO hubo cancelaciones y finalizaciones, salimos
      const inicioHoy = admin.firestore.Timestamp.
        fromDate(now.clone().startOf("day").toDate());
      const finHoy = admin.firestore.Timestamp.
        fromDate(now.clone().endOf("day").toDate());
      const canceladas = await colR
        .where("fechaInicio", ">=", inicioHoy)
        .where("fechaInicio", "<=", finHoy)
        .where("estado", "in", ["cancelado", "finalizado"])
        .get();
      if (canceladas.empty) {
        logger.info("No hubo cancelaciones ni finalizaciones " +
          "hoy → nada que hacer.");
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

      // 4) Extraer PATH de cada espacio afectado
      futuras.docs.forEach((doc) => {
        const raw = doc.get("espacio");
        let path: string | null = null;
        if (raw instanceof admin.firestore.DocumentReference) {
          path = raw.path; // e.g. "espacios/A_1"
        } else if (typeof raw === "string") {
          path = raw.replace(/^\/+/, ""); // remove leading slash
        }
        if (path) {
          const [col, id] = path.split("/");
          if (col === "espacios" && id) {
            toUpdate.add(id);
          } else {
            logger.warn(`Reserva ${doc.id} ruta inesperada: ${raw}`);
          }
        } else {
          logger.warn(`Reserva ${doc.id} sin campo 'espacio' válido`);
        }
      });

      // 5) Para cada espacio: si estaba disponible
      // y tiene reserva futura → marcar false
      const batch = db.batch();
      const finDeHoy = admin.firestore.Timestamp.
        fromDate(now.clone().endOf("day").toDate());
      for (const idEsp of toUpdate) {
        const eRef = db.collection("espacios").doc(idEsp);
        const eSnap = await eRef.get();
        if (!eSnap.exists) {
          logger.warn(`Espacio ${idEsp} no existe.`);
          continue;
        }
        const disponible = eSnap.get("disponible");
        if (disponible === true) {
          const futEsp = await colR
            .where("espacio", "==", eRef)
            .where("fechaInicio", ">", finDeHoy)
            .where("estado", "in", ["pendiente", "confirmado"])
            .limit(1)
            .get();
          if (!futEsp.empty) {
            batch.update(eRef, {disponible: false});
          }
        }
      }

      // 6) Aplicar todas las actualizaciones
      await batch.commit();
      logger.info("✅ Disponibilidad en 'espacios' actualizada.");
    } catch (err) {
      logger.error("❌ Error en actualizarDisponibilidadEspacios:", err);
    }
  }
);
