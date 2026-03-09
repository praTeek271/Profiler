import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { getRecordsBySHN } from "../services/dynamodb.js";

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

    // Query medicalrecordDB via shn-index GSI
    const records = await getRecordsBySHN(shn);

    return res(200, { shn, records });
  } catch (err) {
    console.error("getRecords error:", err);
    return res(500, { message: "Internal server error" });
  }
};
