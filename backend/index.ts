import express, { type Request, type Response } from 'express';

const app = express();

const port = process.env.PORT || 3000;

app.get('/', (_req: Request, res: Response) => {
  res.status(200).json({ message: 'Hurray!! we create our first server on bun js', success: true });
});

app.listen(port, () => {
  console.log(`Server is up and running on port ${port}`);
});
