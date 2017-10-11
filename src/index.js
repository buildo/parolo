const axios = require('axios');
const _ = require('lodash');
const stagger = require('staggerjs').default;
const { Client } = require('pg');
const format = require('pg-format');
const client = new Client(); // picks settings from process.env

const startTime = Date.now();

function get(url, params) {
  return axios({
    url,
    params: _.assign({
      token: process.env.SLACK_TOKEN,
      pretty: 1
    }, params),
    method: 'get'
  });
}

function end() {
  client.end();
  process.exit();
}

client.connect().then(() => {
  return get('https://slack.com/api/users.list')
    .then(res => {
      const members = res.data.members;

      return get('https://slack.com/api/channels.list')
        .then(res => {
          const channels = res.data.channels;
          const asyncMethods = channels.map(c => () => get('https://slack.com/api/channels.history', { channel: c.id, count: 1000 }));

          return stagger(asyncMethods, { maxOngoingMethods: 1, perSecond: Infinity })
            .then(_res => {
              const res = _res.map((r, i) => {
                r.data.messages = r.data.messages.map(m => {
                  m.channel = channels[i];
                  m.member = members.filter(u => u.id === m.user)[0];
                  return m;
                })
                return r;
              });

              const messages = _.flatten(_.flatten(res).map(res => res.data.messages));
              console.log('GOT ' + messages.length +  ' messages');
              const values = messages.map(message => {
                const timestamp = parseFloat(message.ts) * 1000;
                return [message.channel.name + '_' + message.ts, message.ts, message.thread_ts, message.user, message.text, message.channel.id, message.channel.name, message.subtype === 'bot_message', new Date(timestamp).toISOString().slice(0, 19), message.subtype, message.member && message.member.name, message.member && message.member.real_name, message.member && message.member.team_id];
              });

              return client.query('DELETE FROM slack_messages WHERE ' + messages.map(m => 'id = ' + '\'' + m.channel.name + '_' + m.ts + '\'').join(' OR '))
                .then(() => {
                  console.log('Deleted pre-existing messages')
                  return client.query(format('INSERT INTO slack_messages (id, ts, thread_ts, user_id, text, channel_id, channel_name, user_is_bot, posted_on, subtype, user_name, user_real_name, team_id) VALUES %L', values))
                    .then(() => console.log('SUCCESS!', '(Done in:', Date.now() - startTime, 'ms)'))
                    .catch((e) => console.log(e.message))
                })
            });
        })
        .then(end)
        .catch(end);
    })
});
