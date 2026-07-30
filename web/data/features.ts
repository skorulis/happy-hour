import featuresJson from "./features.json";

export type Feature = {
  name: string;
  synonyms?: string[];
};

export const features: Feature[] = featuresJson as Feature[];

const featuresByName = new Map(
  features.map((feature) => [feature.name.toLowerCase(), feature]),
);

export function findFeatureByName(name: string): Feature | undefined {
  return featuresByName.get(name.toLowerCase());
}
