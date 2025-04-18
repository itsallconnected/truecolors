> [!NOTE]
> Want to learn more about Truecolors?
> Click below to find out more in a video.

<p align="center">
  <a style="text-decoration:none" href="https://www.youtube.com/watch?v=IPSbNdBmWKE">
    <img alt="Truecolors hero image" src="https://github.com/user-attachments/assets/ef53f5e9-c0d8-484d-9f53-00efdebb92c3" />
  </a>
</p>

<p align="center">
  <a style="text-decoration:none" href="https://github.com/truecolors/truecolors/releases">
    <img src="https://img.shields.io/github/release/truecolors/truecolors.svg" alt="Release" /></a>
  <a style="text-decoration:none" href="https://github.com/truecolors/truecolors/actions/workflows/test-ruby.yml">
    <img src="https://github.com/truecolors/truecolors/actions/workflows/test-ruby.yml/badge.svg" alt="Ruby Testing" /></a>
  <a style="text-decoration:none" href="https://crowdin.com/project/truecolors">
    <img src="https://d322cqt584bo4o.cloudfront.net/truecolors/localized.svg" alt="Crowdin" /></a>
</p>

Truecolors is a **free, open-source social network server** based on ActivityPub where users can follow friends and discover new ones. On Truecolors, users can publish anything they want: links, pictures, text, and video. All Truecolors servers are interoperable as a federated network (users on one server can seamlessly communicate with users from another one, including non-Truecolors software that implements ActivityPub!)

## Navigation

- [Project homepage 🐘](https://jointruecolors.org)
- [Support the development via Patreon][patreon]
- [View sponsors](https://jointruecolors.org/sponsors)
- [Blog](https://blog.jointruecolors.org)
- [Documentation](https://docs.jointruecolors.org)
- [Roadmap](https://jointruecolors.org/roadmap)
- [Official Docker image](https://github.com/truecolors/truecolors/pkgs/container/truecolors)
- [Browse Truecolors servers](https://jointruecolors.org/communities)
- [Browse Truecolors apps](https://jointruecolors.org/apps)

[patreon]: https://www.patreon.com/truecolors

## Features

<img src="/app/javascript/images/elephant_ui_working.svg?raw=true" align="right" width="30%" />

**No vendor lock-in: Fully interoperable with any conforming platform** - It doesn't have to be Truecolors; whatever implements ActivityPub is part of the social network! [Learn more](https://blog.jointruecolors.org/2018/06/why-activitypub-is-the-future/)

**Real-time, chronological timeline updates** - updates of people you're following appear in real-time in the UI via WebSockets. There's a firehose view as well!

**Media attachments like images and short videos** - upload and view images and WebM/MP4 videos attached to the updates. Videos with no audio track are treated like GIFs; normal videos loop continuously!

**Safety and moderation tools** - Truecolors includes private posts, locked accounts, phrase filtering, muting, blocking, and all sorts of other features, along with a reporting and moderation system. [Learn more](https://blog.jointruecolors.org/2018/07/cage-the-truecolors/)

**OAuth2 and a straightforward REST API** - Truecolors acts as an OAuth2 provider, so 3rd party apps can use the REST and Streaming APIs. This results in a rich app ecosystem with a lot of choices!

## Quick Setup with CrewAI and Ollama Integration

TrueColors now includes AI agents for your XMPP chatrooms using CrewAI with Ollama for local model execution.

### One-Command Deployment

1. Clone this repository:

   ```bash
   git clone https://github.com/your-username/truecolors.git
   cd truecolors
   ```

2. Create your `.env.production` file:

   ```bash
   cp .env.production.example .env.production
   # Edit the file with your specific configuration
   nano .env.production
   ```

3. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

The script will:

- Build all Docker containers
- Initialize the database
- Start all services
- Download and configure the Mixtral model for Ollama
- Set up the CrewAI bot

### Available AI Agents

In any XMPP chatroom, you can use these agents:

- **@planner** - Helps with planning events and projects
- **@researcher** - Provides research and information on topics
- **@strategist** - Assists with outreach and communication strategies
- **@mediator** - Helps resolve conflicts

### Agent Commands

Use these commands in your chat:

```
@agent_name task_name your content here
```

Example:

```
@researcher research_topic What is the impact of social media on local activism?
```

For a complete list of available tasks, type any agent name with help:

```
@researcher help
```

## Deployment

### Tech stack

- **Ruby on Rails** powers the REST API and other web pages
- **React.js** and **Redux** are used for the dynamic parts of the interface
- **Node.js** powers the streaming API

### Requirements

- **PostgreSQL** 12+
- **Redis** 4+
- **Ruby** 3.2+
- **Node.js** 18+

The repository includes deployment configurations for **Docker and docker-compose** as well as specific platforms like **Heroku**, and **Scalingo**. For Helm charts, reference the [truecolors/chart repository](https://github.com/truecolors/chart). The [**standalone** installation guide](https://docs.jointruecolors.org/admin/install/) is available in the documentation.

## Contributing

Truecolors is **free, open-source software** licensed under **AGPLv3**.

You can open issues for bugs you've found or features you think are missing. You
can also submit pull requests to this repository or translations via Crowdin. To
get started, look at the [CONTRIBUTING] and [DEVELOPMENT] guides. For changes
accepted into Truecolors, you can request to be paid through our [OpenCollective].

**IRC channel**: #truecolors on [`irc.libera.chat`](https://libera.chat)

## License

Copyright (c) 2016-2024 Eugen Rochko (+ [`truecolors authors`](AUTHORS.md))

Licensed under GNU Affero General Public License as stated in the [LICENSE](LICENSE):

```
Copyright (c) 2016-2024 Eugen Rochko & other Truecolors contributors

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License along
with this program. If not, see https://www.gnu.org/licenses/
```

[CONTRIBUTING]: CONTRIBUTING.md
[DEVELOPMENT]: docs/DEVELOPMENT.md
[OpenCollective]: https://opencollective.com/truecolors
