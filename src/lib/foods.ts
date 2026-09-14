import catalog from "../data/foods.json";
import { priceRarity } from "./case-mechanics";

export type Food = {
  name: string;
  sub: string;
  price: number;
  rarity: number;
  image: number;
  veg?: boolean;
  quip: string;
  customId?: string;
  placeId?: string;
  restaurant?: string;
  address?: string;
  provinceName?: string;
  districtName?: string;
  stars?: number;
  eatAgain?: boolean;
  photo?: string;
};

type CatalogFood = {
  name: string;
  sub: string;
  price: number;
  image: number;
  veg?: boolean;
  quip: string;
};

export const foods: Food[] = (catalog as CatalogFood[]).map((food) => ({
  ...food,
  rarity: priceRarity(food.price),
}));

export function matchCatalogFood(name: string) {
  const needle = name.trim().toLowerCase();
  if (!needle) return undefined;
  return (
    foods.find((f) => f.name.toLowerCase() === needle) ??
    foods.find(
      (f) =>
        f.name.toLowerCase().includes(needle) ||
        needle.includes(f.name.toLowerCase()),
    )
  );
}
