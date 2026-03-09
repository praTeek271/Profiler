/**
 * Core Domain Models
 */

// =====================
// Patient
// DynamoDB table: patientDB
// PK: shn
// =====================

export interface Patient {
  shn: string;
  name: string;
  dateOfBirth: string; // ISO 8601 date string (YYYY-MM-DD)
  contact: {
    email: string;
    phone?: string;
  };
}

// =====================
// Medical Record
// DynamoDB table: medicalrecordDB
// PK: recordId
// GSI: shn (for per-patient queries)
// =====================

export interface MedicalRecord {
  recordId: string;
  shn: string;
  title: string;
  content?: string;
  filePath?: string;
  createdAt: string; // ISO 8601 date-time
}

// =====================
// Redis Cache
// Key format: patient:<shn>
// TTL: 300 seconds
// Provider: Redis Cloud (external, free tier)
// Caches: Patient demographics only (not records)
// =====================

export type PatientCache = Patient;
