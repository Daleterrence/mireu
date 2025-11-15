# Mireu
A Windower addon for spawning Mireu during Domain Invasion if it fails to appear on your client.

## A note on how this addon works
This addon injects "Update Request" packets to the server to forcibly spawn Mireu on your client as a workaround for the client failing to do so, due to severe lag. 
You **SHOULD NOT** change any of the addon's code unless you are sure of what you are doing. 

Whilst this addon contains safeguards and checks to ensure you're in a scenario where these packets would be sent to the server naturally, there is always a risk. 

**If you are uncomfortable with the idea of packet injection, please do not use this addon**.

## How it works
This addon queries the server about Mireu's current position, and spawn status, via packet injection. This is a packet normally sent whenever you are in range of any mob, and normally, you will receive a response. 

However, due to the critical mass of players, trusts, pets, etc, during a Mireu spawn, frequently the packet naturally sent to query Mireu is never received correctly by the server, which results in it failing to appear on your client. 
This addon basically attempts to retry that packet until it is successful, by trying for 20 seconds, in 4 second intervals after you start an attempt, using `//mireu`. There are multiple safeguards in place to prevent this appearing irregular
to the server, such as;
- A check on your current zone.
- A check on the target ID you're sending to the server.
- Spam protection, you must wait for an attempt to time out, before you may try again. Once spawned successfully, the addon will stop any active attempt.
- Not sending the packet if Mireu has already appeared on your client.
- Requiring Elvorseal to ensure you're in the right place on the map to be sending that request, and to act as a fail-safe in case the zone check does not work correctly for whatever reason.

## How to Use
- Download the latest release and place the Mireu folder in the .zip in `Windower\addons`
- Be in at a Mireu spawn.
- Type `//lua load mireu`
- Type `//mireu`

That's it. That's the addon. Let me know via opening an issue if there's any problems with this, I tested it to the best of my ability considering its an enemy that only appears once every so often.

