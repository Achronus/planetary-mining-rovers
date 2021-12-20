# Planetary Mining Rovers

This repository focuses on three scenarios that use multiple agents cooperatively to mine resources and deposit them back at their starting point (base). Each environment increases in difficulty where the first contains one agent, the second uses two agents, and the third uses four agents.

## Scenario 1

![Scenario 1 demo](demos/s1.gif)

Scenario 1 is the simplest of the scenarios, requiring the collection of one resource using one agent. It follows the `basic_agent.asl` to scan and mine a single gold node in a 10x10 environment. Being a solo agent, it uses a combination of scanning and mining with a scan radius of 3 and a capacity of 3. The agent moves around the environment in a pattern, scanning for the resource. Once found, it uses the A* algorithm to find the shortest path and mines the ore until maximum capacity. Next, it uses the A* algorithm again to return home and deposit the ore. The agent moves back and forth between the resource and the base until depleted.

## Scenario 2

![Scenario 2 demo](demos/s2.gif)

Scenario 2 requires the collection of four resource nodes using two agents. It uses a combination of a dedicated scanner `scanner_s2.asl` that communicates resource node locations and A* paths to a dedicated miner `miner_s2.asl`. The miner waits for the scanner to finish scanning the map (finding all resource nodes) before signalled to begin mining operations. The miner begins mining the nodes in sequence, fully depleting a node before moving on to the next one.

## Scenario 3

![Scenario 3 demo](demos/s3.gif)

Scenario 3 requires the collection of eight resource nodes, split into two types (gold and diamond) using four agents. The implementation is identical to scenario 2 but with minor additions to accommodate the additional agents. It uses two dedicated scanners, both following the `scanner_s3.asl` agent format, where the agents are assigned separate quadrants of the map (half each). The agents move to their quadrants and then begin scanning, sending the found resources to each scanner (preventing duplicate resource locations) and the respective miner. When the scanners get low on energy, they return to base, concluding the map scanning and signal the miners to begin mining. The miners cannot start mining until both scanners have returned to base. The remaining two agents are miners, one for each resource, where both follow the `miner_s3.asl` agent format. As with scenario 2, the agents deplete a resource and deposit it back at base before moving to the next one.
