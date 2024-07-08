import { Utilities } from "../support/utilities";

export class IScientificDomain {
  name: string;
  description: string;
  parent?: string;
}

export const ScientificDomainFactory = {
  create: (args: { [field: string]: string } = {}): IScientificDomain => ({
    name: Utilities.getUUID4(),
    description: Utilities.getRandomString(8).toLowerCase(),
    ...args,
  }),
};
