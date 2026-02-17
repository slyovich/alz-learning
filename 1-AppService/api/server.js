const express = require('express');

const app = express();
const port = process.env.PORT || 3000

app.get('/', async (req, res) => {
  try {
    const response = await fetch('https://jsonplaceholder.typicode.com/posts', {
      signal: AbortSignal.timeout(10000)
    });

    if (!response.ok) {
      console.error('API responded with status', response.status);
      return res.status(502).json({ message: `API error: ${response.status}` });
    }
    
    const posts = await response.json();
    const first5Posts = posts.slice(0, 5);
    console.log('Successfully called https://jsonplaceholder.typicode.com/posts');
    res.json({ message: 'Result of the call to https://jsonplaceholder.typicode.com/posts', posts: first5Posts });
  } catch (error) {
    if (error.name === 'TimeoutError' || error.code === 'ABORT_ERR') {
      console.error('Timeout calling https://jsonplaceholder.typicode.com/posts', error);
      res.status(504).json({ message: 'Timeout calling https://jsonplaceholder.typicode.com/posts' });
    } else {
      console.error('Error calling https://jsonplaceholder.typicode.com/posts', error);
      res.status(500).json({ message: 'Error calling https://jsonplaceholder.typicode.com/posts' });
    }
  }
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
