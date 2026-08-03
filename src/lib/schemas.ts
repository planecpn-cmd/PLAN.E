import { z } from 'zod';
import { isNepaliPhone } from './format';

export const signUpSchema = z.object({
  fullName: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  phone: z.string().refine(isNepaliPhone, 'Invalid Nepali mobile number (+97798XXXXXXXX)'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

export const loginSchema = z.object({
  emailOrPhone: z.string().min(3, 'Required'),
  password: z.string().min(1, 'Password required'),
});

export const bookingFormSchema = z.object({
  experienceId: z.string().uuid(),
  departureId: z.string().uuid(),
  adults: z.number().int().min(1, 'At least 1 adult required'),
  children: z.number().int().min(0).default(0),
  contactName: z.string().min(2, 'Contact name required'),
  contactPhone: z.string().refine(isNepaliPhone, 'Valid Nepali phone required'),
  addons: z.array(z.object({
    code: z.string(),
    label: z.string(),
    price_paisa: z.number().int().nonnegative(),
  })).default([]),
});

export const reviewSchema = z.object({
  bookingId: z.string().uuid(),
  experienceId: z.string().uuid(),
  rating: z.number().int().min(1).max(5),
  title: z.string().optional(),
  body: z.string().min(10, 'Review body must be at least 10 characters'),
  photos: z.array(z.string().url()).default([]),
});

export const hostApplicationSchema = z.object({
  categoryId: z.string().uuid().optional(),
  title: z.string().min(5, 'Title must be at least 5 characters').optional(),
  description: z.string().min(20, 'Description must be at least 20 characters').optional(),
  location: z.string().optional(),
  photos: z.array(z.string()).default([]),
  verificationDocPath: z.string().optional(),
});
