swall-client
============

## What is Social Wall (swall)

Users can post comments by accessing a specific web page using their mobile phones or laptops and their comments would be immediately displayed as Danmakus (flying commentary subtitles) on the activity page. The activity organizer could use projectors or other devices to present the activity page at the site and display and share users' comment in real-time.

Social Wall is separated to 2 parts, the server-side and the client-side. Server-side swall (https://swall.me) is a public web service, runs on our server and provides an interface for users to enter comments. Anyone can create his/her own activity interface on it. Client-side swall is supposed to run on the organizer's PC, which takes charge of realtime communication and background related stuff. It provides a dashboard for organizers to adjust preferences and control backgrounds, and a wall interface which should be projected or displayed on the screen, publicly.

## Features

- Real-time danmaku, hardware accelerated.
- Multiple danmaku colors as you wish.
- Keyword filters.
- Display video / image backgrounds.
- Dynamically add backgrounds and switch smoothly.
- Locally store background resources: no extra traffic.
- Platform as a service (PaaS) & open-source.

## Client-side requirements

- Chrome, for displaying the wall and the dashboard.
- Node.js, for running the client-side application.

## Client-side dependencies

- ffmpeg, for taking snapshot posters for video backgrounds.
- imagemagick, for generating thumbnails for image backgrounds.

## Initialize

```bash
npm install  # install modules
cp config.cson.default config.cson
cp db.sqlite.default db.sqlite
grunt  # compile all files
```

## Run

```bash
npm start    # start the client applica
```

## Interfaces

### Dashboard (Chrome required)

http://localhost:2333/control

### Wall (Chrome required)

http://localhost:2333/wall

## Authors

[swall-server](https://github.com/breeswish/swall-server): ShiehShieh

[swall-client](https://github.com/breeswish/swall-client): Breezewish

## License

swall-client is released under MIT license.
