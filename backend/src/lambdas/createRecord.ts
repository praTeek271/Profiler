import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { randomBytes } from "crypto";
import { CreateMedicalRecordSchema } from "../types/schemas.js";
import { getPatientBySHN, putRecord } from "../services/dynamodb.js";
import { MedicalRecord } from "../types/models.js";

function generateRecordId(): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  const bytes = randomBytes(10);
  let id = "";
  for (let i = 0; i < 10; i++) {
    id += chars[bytes[i] % chars.length];
  }
  return `rec-${id}`;
}

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

    const parsed = CreateMedicalRecordSchema.safeParse(
      JSON.parse(event.body ?? "{}"),
    );
    if (!parsed.success) {
      return res(400, { message: parsed.error.errors[0].message });
    }

    // Verify patient exists before writing
    const patient = await getPatientBySHN(shn);
    if (!patient) {
      return res(404, { message: "Patient not found" });
    }

    const { title, content, filePath } = parsed.data;

    const record: MedicalRecord = {
      recordId: generateRecordId(),
      shn,
      title,
      ...(content !== undefined && { content }),
      ...(filePath !== undefined && { filePath }),
      createdAt: new Date().toISOString(),
    };

    await putRecord(record);

    return res(201, { record });
  } catch (err) {
    console.error("createRecord error:", err);
    return res(500, { message: "Internal server error" });
  }
};
