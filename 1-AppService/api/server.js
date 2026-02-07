const express = require('express');

const app = express();
const port = process.env.PORT || 3000

app.get('/', async (req, res) => {
  try {
    const posts = await fetch('https://jsonplaceholder.typicode.com/posts').then(res => res.json());
    const first10Posts = posts.slice(0, 10);

    console.log('Successfully called https://jsonplaceholder.typicode.com/posts');

    res.json({ message: 'Result of the call to https://jsonplaceholder.typicode.com/posts', posts: first10Posts });
  } catch (error) {
    console.error('Error calling https://jsonplaceholder.typicode.com/posts', error);

    res.status(500).json({ message: 'Error calling https://jsonplaceholder.typicode.com/posts' });
  }
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
