const express = require('express');
const app = express();
const port = process.env.PORT || 3000

app.get('/', async (req, res) => {
  // Call https://jsonplaceholder.typicode.com/posts and get the 10 first posts
  const posts = await fetch('https://jsonplaceholder.typicode.com/posts').then(res => res.json());
  const first10Posts = posts.slice(0, 10);

  res.json({ message: 'Result of the call to https://jsonplaceholder.typicode.com/posts', posts: first10Posts });
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
