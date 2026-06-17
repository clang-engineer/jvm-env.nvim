local internal = require("jvm-env.detect")._internal

describe("nat_key", function()
  it("extracts numeric segments as numbers", function()
    assert.are.same({ 21, 0, 10 }, internal.nat_key("jdk-21.0.10"))
    assert.are.same({ 17 }, internal.nat_key("/usr/lib/jvm/jdk-17"))
    assert.are.same({ 21, 0, 1 }, internal.nat_key("21.0.1-tem"))
  end)
end)

describe("lt_natural", function()
  it("orders jdk-21.0.10 after jdk-21.0.9", function()
    assert.is_true(internal.lt_natural("jdk-21.0.9", "jdk-21.0.10"))
    assert.is_false(internal.lt_natural("jdk-21.0.10", "jdk-21.0.9"))
  end)

  it("orders by leading number when major versions differ", function()
    assert.is_true(internal.lt_natural("jdk-11.0.20", "jdk-21.0.1"))
    assert.is_false(internal.lt_natural("jdk-21.0.1", "jdk-11.0.20"))
  end)

  it("falls back to string compare on numeric tie", function()
    assert.is_true(internal.lt_natural("21.0.1-tem", "21.0.1-zulu"))
  end)

  it("is irreflexive", function()
    assert.is_false(internal.lt_natural("jdk-21.0.1", "jdk-21.0.1"))
  end)
end)
