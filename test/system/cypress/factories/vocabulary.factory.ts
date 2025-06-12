import { Utilities } from "../support/utilities";

export class IVocabulary {
  name: string;
  description: string;
  parent?: string;
  eid?: string;
}

export const VocabularyFactory = {
  create: (args: { [field: string]: string } = {}): IVocabulary => ({
    name: Utilities.getUUID4(),
    description: Utilities.getRandomString(8).toLowerCase(),
    ...args,
  }),
};
