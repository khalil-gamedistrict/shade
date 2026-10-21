import { test } from "node:test";
import assert from "node:assert/strict";
import { add, subtract, divide } from "../src/calculator.js";

test("add do numbers jorta hai", () => {
  assert.equal(add(2, 3), 5);
});

test("subtract sahi minus karta hai", () => {
  assert.equal(subtract(10, 4), 6);
});

test("divide zero pe error deta hai", () => {
  assert.throws(() => divide(1, 0));
});
