import {Utilities} from "../support/utilities";

export class IProviders {
    basicName: string;
    basicAbbreviation: string;
    basicWebpage_url: string;
    marketingDescription: string;
    marketingMultimedia: string;
    classificationScientificDomains: string[];
    classificationTag: string;
    locationStreet:string;
    locationPostCode:string;
    locationCity:string;
    locationCountry:string;
    contactFirstname:string;
    contactLastname:string;
    contactEmail:string;
    publicContactsEmail:string;
    adminFirstName?:string;
    adminLastName?:string;
    adminEmail?:string;
}

export const ProvidersFactory = {
    create: (args: {[field: string]: string} = {}): IProviders => ({
        basicName: Utilities.getUUID4(),
        basicAbbreviation: Utilities.getUUID4(),
        basicWebpage_url: 'https://example.org/',
        marketingDescription: Utilities.getRandomString(8).toLowerCase(),
        marketingMultimedia: "https://example.org/",
        classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
        classificationTag: Utilities.getRandomString(8).toLowerCase(),
        locationStreet:Utilities.getRandomString(8).toLowerCase(),
        locationPostCode:Utilities.getRandomString(8).toLowerCase(),
        locationCity:Utilities.getRandomString(8).toLowerCase(),
        locationCountry:"Poland",
        contactFirstname:Utilities.getRandomString(8).toLowerCase(),
        contactLastname:Utilities.getRandomString(8).toLowerCase(),
        contactEmail:Utilities.getRandomEmail(),
        publicContactsEmail:Utilities.getRandomEmail(),
        ...args
    })
};