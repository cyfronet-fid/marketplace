import {Utilities} from "../support/utilities";

export class IOffer {
    name: string;
    description: string;
    orderType: string;
    orderAccessUrl: string;
}

export const OfferFactory = {
    create: (args: {[field: string]: string} = {}): IOffer => ({
        name: Utilities.getUUID4(),
        description: Utilities.getRandomString(8).toLowerCase(),
        orderType: 'order_required',
        orderAccessUrl: Utilities.getRandomUrl(),
        ...args
    })
};