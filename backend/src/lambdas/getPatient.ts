import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { getPatientBySHN } from "../services/dynamodb.js";
import { getPatientCache, setPatientCache } from "../services/redis.js";

function res(statusCode: number, body: unknown): APIGatewayProxyResult {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  };
}

export const handler = async (
  event: APIGatewayProxyEvent,
): Promise<APIGatewayProxyResult> => {
  try {
    const shn = event.pathParameters?.shn;
    if (!shn) {
      return res(400, { message: "SHN is required" });
    }

    // 1. Cache-first: check Redis
    const cached = await getPatientCache(shn);
    if (cached) {
      return res(200, { patient: cached });
    }

    // 2. Cache miss: query DynamoDB
    const patient = await getPatientBySHN(shn);
    if (!patient) {
      return res(404, { message: "Patient not found" });
    }

    // 3. Populate cache for next request
    await setPatientCache(shn, patient);

    return res(200, { patient });
  } catch (err) {
    console.error("getPatient error:", err);
    return res(500, { message: "Internal server error" });
  }
};
