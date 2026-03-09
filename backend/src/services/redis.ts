import Redis from "ioredis";
import { Patient } from "../types/models.js";

const REDIS_URL = process.env.REDIS_URL!;
const CACHE_TTL_SECONDS = 300; // 5 minutes

// Reuse the same connection across Lambda invocations (warm starts)
let redis: Redis | null = null;

function getRedis(): Redis {
  if (!redis) {
    // ioredis handles TLS automatically when the URL scheme is rediss://
    redis = new Redis(REDIS_URL, { lazyConnect: false });
  }
  return redis;
}

const cacheKey = (shn: string) => `patient:${shn}`;

export async function getPatientCache(shn: string): Promise<Patient | null> {
  const data = await getRedis().get(cacheKey(shn));
  return data ? (JSON.parse(data) as Patient) : null;
}

export async function setPatientCache(
  shn: string,
  patient: Patient,
): Promise<void> {
  await getRedis().set(
    cacheKey(shn),
    JSON.stringify(patient),
    "EX",
    CACHE_TTL_SECONDS,
  );
}

export async function invalidatePatientCache(shn: string): Promise<void> {
  await getRedis().del(cacheKey(shn));
}
