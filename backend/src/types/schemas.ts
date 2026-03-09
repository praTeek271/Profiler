import { z } from "zod";

/**
 * Zod Schemas for Runtime Validation
 */

// =====================
// Shared Validators
// =====================

export const SHNSchema = z
  .string()
  .regex(/^SHN-[A-Z0-9]{10}$/, "Invalid SHN format. Must be SHN-XXXXXXXXXX");

// =====================
// Patient Schemas
// =====================

export const CreatePatientSchema = z.object({
  name: z.string().min(1, "Name is required"),
  dateOfBirth: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, "Date must be YYYY-MM-DD"),
  email: z.string().email("Invalid email address"),
  phone: z.string().optional(),
});

export type CreatePatientInput = z.infer<typeof CreatePatientSchema>;

// =====================
// Medical Record Schemas
// =====================

export const CreateMedicalRecordSchema = z.object({
  title: z.string().min(1, "Title is required"),
  content: z.string().optional(),
  filePath: z.string().optional(),
});

export type CreateMedicalRecordInput = z.infer<
  typeof CreateMedicalRecordSchema
>;
