import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
  QueryCommand,
} from "@aws-sdk/lib-dynamodb";
import { Patient, MedicalRecord } from "../types/models.js";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const PATIENT_TABLE = process.env.PATIENT_TABLE!;
const RECORDS_TABLE = process.env.RECORDS_TABLE!;

// =====================
// patientDB  (PK: shn)
// =====================

export async function putPatient(patient: Patient): Promise<void> {
  await docClient.send(
    new PutCommand({
      TableName: PATIENT_TABLE,
      Item: patient,
    }),
  );
}

export async function getPatientBySHN(shn: string): Promise<Patient | null> {
  const result = await docClient.send(
    new GetCommand({
      TableName: PATIENT_TABLE,
      Key: { shn },
    }),
  );
  return result.Item ? (result.Item as Patient) : null;
}

// =====================
// medicalrecordDB  (PK: recordId, GSI: shn-index on shn)
// =====================

export async function putRecord(record: MedicalRecord): Promise<void> {
  await docClient.send(
    new PutCommand({
      TableName: RECORDS_TABLE,
      Item: record,
    }),
  );
}

export async function getRecordsBySHN(shn: string): Promise<MedicalRecord[]> {
  const result = await docClient.send(
    new QueryCommand({
      TableName: RECORDS_TABLE,
      IndexName: "shn-index",
      KeyConditionExpression: "shn = :shn",
      ExpressionAttributeValues: { ":shn": shn },
    }),
  );
  return (result.Items ?? []) as MedicalRecord[];
}
