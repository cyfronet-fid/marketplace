import { Utilities } from "../support/utilities";

export class ICategory {
  name: string;
  description: string;
  parent?: string;
}

export const CategoryFactory = {
  create: (args: { [field: string]: string } = {}): ICategory => ({
    name: Utilities.getUUID4(),
    description: Utilities.getRandomString(8).toLowerCase(),
    ...args,
  }),
};
