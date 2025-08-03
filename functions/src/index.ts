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
