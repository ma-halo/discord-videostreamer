const Discord = require('discord.js');
const puppeteer = require('puppeteer');
const child_process = require('child_process');

const client = new Discord.Client();
const config = {
    token: process.env.TOKEN,
    serverId: process.env.SERVER_ID,
    textChannelID: process.env.TEXT_CHANNEL_ID,
    voiceChannelID: process.env.VOICE_CHANNEL_ID,
};

let player = null;

// Sign in to Discord using the API.
await client.login(config.token);

// Open a browser to Discord web.
const browser = await puppeteer.launch({ headless: false, userDataDir: './data' });

const webClient = (await browser.pages()) [0]; // Use the default tab instead of making a new one.
await webClient.goto(`https://discord.com/channels/${config.serverId}`, { waitUntil: 'networkidle0' });

// Attempt to join the voice channel.
const voiceChannelSelector = `a[data-list-item-id="channels___${config.voiceChannelID}"]`;

await webClient.waitForSelector(voiceChannelSelector, { timeout: 0 });
await webClient.evaluate(v => document.querySelector(v).click(), voiceChannelSelector);

client.on('message', handleCommands);

// Only accept commands from a specific channel.
if (msg.channel.id !== config.textChannelID)
    return;

// Require users to be in the same voice channel as us.
if (msg.member.voiceChannelID !== config.voiceChannelID)
    return;

if (msg.content === '.stop' && player !== null)
{
    // Stop the current video.
    try {
        process.kill(player.pid, 'SIGTERM');
        await msg.delete();
    } catch (e) {}

    return;
}

// Check if this is a video command message.
const command = msg.content.split(' ');

if (command[0] !== '.v' || command.length < 2)
    return;

// Handle non-embedding URLs.
let url = command[1];

if (url.startsWith('<') && url.endsWith('>'))
    url = url.substr(1, url.length - 2);

// Remove the message so we don't clutter up the channel.
try { await msg.delete(); } catch (e) {}

// If a video is currently playing, stop it.
if (player !== null)
    try { process.kill(player.pid, 'SIGINT'); } catch (e) {}

await webClient.evaluate(() => {
    const enableVideoButton = document.querySelector('button[aria-label="Turn On Camera"]');
    const disableVideoButton = document.querySelector('button[aria-label="Turn Off Camera"]');

    if (disableVideoButton !== null)
        return;

    if (enableVideoButton !== null)
        return enableVideoButton.click();
});

player = child_process.spawn('./playvideo.sh', [url]);

player.on('close', async (code) => {
    // A new video is about to start -- keep the camera active.
    if (code === 2)
        return;

    // Regular exit or termination -- turn the camera off.
    await webClient.evaluate(() => {
        const disableVideoButton = document.querySelector('button[aria-label="Turn Off Camera"]');

        if (disableVideoButton !== null)
            return disableVideoButton.click();
    });
});

