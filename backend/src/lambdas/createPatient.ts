import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { randomBytes } from "crypto";
import { CreatePatientSchema } from "../types/schemas.js";
import { putPatient } from "../services/dynamodb.js";
import { Patient } from "../types/models.js";

function generateSHN(): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  const bytes = randomBytes(10);
  let id = "";
  for (let i = 0; i < 10; i++) {
    id += chars[bytes[i] % chars.length];
  }
  return `SHN-${id}`;
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
    const parsed = CreatePatientSchema.safeParse(
      JSON.parse(event.body ?? "{}"),
    );
    if (!parsed.success) {
      return res(400, { message: parsed.error.errors[0].message });
    }

    const { name, dateOfBirth, email, phone } = parsed.data;
    const shn = generateSHN();

    const patient: Patient = {
      shn,
      name,
      dateOfBirth,
      contact: {
        email,
        ...(phone !== undefined && { phone }),
      },
    };

    await putPatient(patient);

    return res(201, { shn, patient });
  } catch (err) {
    console.error("createPatient error:", err);
    return res(500, { message: "Internal server error" });
  }
};
