const axios = require('axios');
const { Client } = require('pg');

function get(url, params) {
  return axios({
    url,
    params: Object.assign({
      token: process.env.SLACK_TOKEN,
      pretty: 1
    }, params),
    method: 'get'
  });
}

function insertMessageInDB(message) {
  const text = 'INSERT INTO slack_messages(id, ts, thread_ts, user_id, text, channel_id, channel_name, user_is_bot, posted_on, subtype, user_name, user_real_name, team_id) VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) RETURNING *'
  const timestamp = parseFloat(message.ts) * 1000;
  const values = [message.channel.name + '_' + message.ts, message.ts, message.thread_ts, message.user, message.text, message.channel.id, message.channel.name, message.subtype === 'bot_message', new Date(timestamp).toISOString().slice(0, 19), message.subtype, message.member && message.member.name, message.member && message.member.real_name, message.member && message.member.team_id];
  return client.query(text, values)
    .then(() => console.log('SUCCESS'))
    .catch(e => console.log('ERROR', e.message));
}

function parolo(message, client) {
  return client.connect().then(() => {

    const maybeGetUser = (message) => {
      if (message.user) {
        return get('https://slack.com/api/users.info', { user: message.user });
      } else {
        return Promise.resolve(null);
      }
    }

    return maybeGetUser(message)
      .then(res => {
        const user = res && res.data.user;

        console.log('User info:\n', user ? JSON.stringify(user, null, 2) : 'NULL');

        return get('https://slack.com/api/channels.info', { channel: message.channel })
          .then(res => {
            const channel = res.data.channel;

            console.log('Channel info:\n', JSON.stringify(channel, null, 2));

            message.channel = channel;
            message.member = user;

            return insertMessageInDB(message);
          });
      });
  });
};

// Verify Url - https://api.slack.com/events/url_verification
function verify(data, callback) {
  if (data.token === process.env.SLACK_VERIFICATION_TOKEN) {
    callback(null, data.challenge);
  } else {
    callback('Verification failed');
  }
}

// Lambda handler
exports.handler = (data, context, callback) => {
  console.log('Received message:\n', JSON.stringify(data, null, 2));

  const client = new Client(); // picks settings from process.env

  if (data.type === 'event_callback') { // https://api.slack.com/events/message
    parolo(data.event, client).then(() => {
      client.end();
      callback();
    });
  } else if (data.type === 'url_verification') {
    verify(data, callback);
  }
};
