import { TimegraphClient } from "@analog-labs/timegraph-js";
const timeGraphClient = new TimegraphClient({
  url: "https://timegraph.testnet.analog.one/graphql", // A url to Watch GraphQL instance.
  sessionKey:
    "", // 填写生成的ssk
});


const response = await timeGraphClient.view.data({
  hashId: "QmcuCmr7kSizrb362WQCyfvefTJ4HKJwnGYcoiLPKQxYUE",
  fields: ["_clock", "_index", "tick"],
  limit: "5",
});
console.log(response);


const aliasResponse = await timeGraphClient.alias.add({
  name: "oooooyoung",
  hashId: "QmcuCmr7kSizrb362WQCyfvefTJ4HKJwnGYcoiLPKQxYUE",
  identifier: "oooooyoungtestquery",
});
console.log(aliasResponse);

const response2 = await timeGraphClient.view.data({
  hashId: "QmcuCmr7kSizrb362WQCyfvefTJ4HKJwnGYcoiLPKQxYUE",
  fields: ["_clock", "_index", "tick"],
  limit: "3",
});
console.log(response2);
