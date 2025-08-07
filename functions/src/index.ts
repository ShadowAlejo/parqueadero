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
  {schedule: "*/45 * * * *", timeZone: TZ},
  async () => {
    try {
      // Hora actual ajustada a la zona horaria
      const now = moment().tz(TZ);
      // Usamos startOf('minute') para asegurarnos que
      // la hora y minutos estén correctos
      const horaAct = now.clone().startOf("minute");
      const start = now.clone().startOf("day");
      const end = now.clone().endOf("day");
      const db = admin.firestore();
      const res = db.collection("reservaciones");
      const impact = new Set<string>();

      // 1) Salir si aún no son las 7 AM
      if (horaAct.hour() < 7) {
        logger.info(`⏳ Aún no son las 6 AM (${horaAct.format("HH:mm")}). 
        Se omite la ejecución.`);
        return;
      }

      // 2) Salir si son más de las 18:15
      if (horaAct.hour() > 18 || (horaAct.hour() === 18 &&
       horaAct.minute() > 15)) {
        logger.info(`⏳ Paso a las 18:20 (${horaAct.format("HH:mm")}).
        Se omite la ejecución.`);
        return;
      }

      const tsStart = admin.firestore.Timestamp.
        fromDate(start.toDate());
      const tsEnd = admin.firestore.Timestamp.
        fromDate(end.toDate());

      // 1) Obtener reservaciones de HOY (estado pendiente o confirmado)
      const snap = await res
        .where("fechaInicio", ">=", tsStart)
        .where("fechaInicio", "<=", tsEnd)
        .where("estado", "in", ["pendiente", "confirmado"])
        .get();

      // 2) Finalizar reservaciones del día actual
      // si ya han pasado su hora de finalización
      const batchR = db.batch();
      snap.docs.forEach((doc) => {
        const data = doc.data();
        // horaFin es un string como "18:00"
        const horaFinStr = data.horaFin as string;
        // Convertir horaFin a un objeto moment
        const finM = moment(horaFinStr, "HH:mm").tz(TZ);

        // Solo procesar si la reservación es del día actual
        // y la hora de finalización ya ha pasado
        if (
          // Comprobamos si la hora de fin ya pasó en minutos
          finM.isBefore(horaAct, "minute") &&
          // Aseguramos que es del día actual
          finM.isSameOrAfter(start, "day")
        ) {
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

      // 3) Actualizar disponibilidad de espacios,
      // solo si la hora es antes de las 16:00
      if (horaAct.hour() < 18) {
        const batchE = db.batch();
        for (const path of impact) {
          const eRef = db.doc(path);

          // 3.1) ¿Reservas activas hoy?
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
      }

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
  {schedule: "*/20 * * * *", timeZone: TZ},
  async () => {
    try {
      const now = moment().tz(TZ);
      const hora = now.hour(); const min = now.minute();

      // 1) Sólo después de las 18:20
      if (hora < 18 || (hora === 18 && min < 20)) {
        logger.info("Antes de 18:10 → no se actualiza.");
        return;
      }

      // 2) Para a las 19:10
      if (hora > 19 || (hora === 19 && min > 10)) {
        logger.info("Despues de 19:10 → no se actualiza.");
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
