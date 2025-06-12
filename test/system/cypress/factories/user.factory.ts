import { Utilities } from "../support/utilities";

export interface IUser {
  name?: string;
  first_name?: string;
  last_name?: string;
  email?: string;
  password: string;
  roles?: string[];
}

export const UserFactory = {
  create: (args: { [field: string]: string | string[] } = {}) => ({
    name: "name_" + Utilities.getRandomString(8),
    first_name: "first_name_" + Utilities.getRandomString(8),
    last_name: "last_name_" + Utilities.getRandomString(8),
    email: "email_" + Utilities.getRandomEmail(),
    password: "password_" + Utilities.getRandomString(12),
    ...args,
  }),
};
