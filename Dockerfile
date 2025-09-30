FROM node:20-alpine
COPY --from=ghcr.io/gleam-lang/gleam:v1.11.1-erlang-alpine /bin/gleam /bin/gleam
COPY . .
RUN gleam build
CMD ["gleam", "run", "-m", "lustre/dev", "start"]
