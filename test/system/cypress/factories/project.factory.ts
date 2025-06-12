import { Utilities } from "../support/utilities";

export class IProject {
  name: string;
  reason: string;
  scientificDomains?: string[];
  additionalInformation: string;
  customerTypology: "Single user" | "Representing a research community";
  email: string;
  organization: string;
  department: string;
  countryOfOrigin: string;
  webpage: string;
}

export const ProjectFactory = {
  create: (args: { [field: string]: string } = {}): IProject => ({
    name: Utilities.getRandomString(),
    reason: Utilities.getRandomString(),
    scientificDomains: ["Agricultural Biotechnology", "Agricultural Sciences"],
    additionalInformation: Utilities.getRandomString(),
    customerTypology: "Single user",
    email: Utilities.getRandomEmail(),
    organization: Utilities.getRandomString(8).toLowerCase(),
    department: Utilities.getRandomString(8).toLowerCase(),
    countryOfOrigin: "Albania",
    webpage: Utilities.getRandomUrl(),
    ...args,
  }),
};
