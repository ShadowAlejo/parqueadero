/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

/* eslint-disable */

// functions/src/index.ts

import * as admin from "firebase-admin";
admin.initializeApp();
const db = admin.firestore();

const { onSchedule } = require("firebase-functions/v2/scheduler") as {
  onSchedule: (
    opts: { schedule: string; timeZone?: string },
    fn: (evt: { time: string }) => Promise<unknown>
  ) => any;
};

export const monitorearFinalizacionReservacionesHoy = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "America/Guayaquil",
  },
  async (event) => {
    try {
      // 1) Fecha actual y principio del día, en zona America/Guayaquil
      const ahora = new Date(event.time);
      const inicio = new Date(ahora);
      inicio.setHours(0, 0, 0, 0);

      const tInicio = admin.firestore.Timestamp.fromDate(inicio);
      const tAhora  = admin.firestore.Timestamp.fromDate(ahora);

      console.log(`Monitoreo iniciado. Rango: ${inicio.toISOString()} → ${ahora.toISOString()}`);

      // 2) Obtén pendientes y confirmados usando índice (estado, fechaFin)
      const [pendientes, confirmados] = await Promise.all([
        db.collection("reservaciones")
          .where("estado", "==", "pendiente")
          .where("fechaFin", ">=", tInicio)
          .where("fechaFin", "<=", tAhora)
          .get(),
        db.collection("reservaciones")
          .where("estado", "==", "confirmado")
          .where("fechaFin", ">=", tInicio)
          .where("fechaFin", "<=", tAhora)
          .get(),
      ]);

      console.log(`Encontradas: pendientes=${pendientes.size}, confirmadas=${confirmados.size}`);

      const batch = db.batch();
      const espaciosARevisar = new Set<admin.firestore.DocumentReference>();

      // 3) Marca como finalizado las reservas que ya pasaron su hora tope
      [...pendientes.docs, ...confirmados.docs].forEach((doc) => {
        const data = doc.data() as {
          fechaFin: admin.firestore.Timestamp;
          horaFin?: string;
          espacio: admin.firestore.DocumentReference;
        };

        // Parseo seguro de horaFin
        const [hRaw, mRaw] = (data.horaFin || "18:00").split(":");
        const h = parseInt(hRaw, 10) || 18;
        const m = parseInt(mRaw, 10) || 0;

        const fechaFin = data.fechaFin.toDate();
        fechaFin.setHours(Math.min(h, 18), h > 18 ? 0 : m, 0, 0);

        if (ahora > fechaFin) {
          batch.update(doc.ref, { estado: "finalizado" });
          espaciosARevisar.add(data.espacio);
        }
      });

      console.log(`Reservas a finalizar: ${espaciosARevisar.size}`);

      // 4) Para cada espacio, verifica si aún quedan reservas activas
      await Promise.all(
        Array.from(espaciosARevisar).map(async (espRef) => {
          const activos = await db
            .collection("reservaciones")
            .where("espacio", "==", espRef)
            .where("estado", "in", ["pendiente", "confirmado"])
            .get();

          if (activos.empty) {
            batch.update(espRef, { disponible: true });
          }
        })
      );

      // 5) Aplica todos los cambios
      await batch.commit();
      console.log("Batch aplicado. Monitoreo completado sin errores.");
    } catch (err) {
      // Usamos console.error en lugar de logger.error para evitar el bug de 'seconds'
      console.error("Error en monitorearFinalizacionReservacionesHoy:", err);
      throw err;
    }

    return null;
  }
);
