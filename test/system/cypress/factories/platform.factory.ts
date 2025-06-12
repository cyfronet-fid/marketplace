import { Utilities } from "../support/utilities";

export class IPlatform {
  name: string;
}

export const PlatformFactory = {
  create: (args: { [field: string]: string } = {}): IPlatform => ({
    name: Utilities.getUUID4(),
    ...args,
  }),
};
