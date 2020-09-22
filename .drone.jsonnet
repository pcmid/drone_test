local PipelineTesting = {
  kind: "pipeline",
  name: "testing",
  platform: {
    os: "linux",
    arch: "amd64",
  },
  steps: [
    {
      name: "test",
      image: "golang",
      pull: "always",
      environment: {
        GO111MODULE: "on",
      },
      commands: [
        "go test ",
      ],
    },
  ],
  trigger: {
    branch: [ "master" ],
  },
};
local PipelineBuild(os="linux", arch="amd64") = {
  kind: "pipeline",
  name: os + "-" + arch,
  platform: {
    os: os,
    arch: arch,
  },
  steps: [
    {
      name: "build-push",
      image: "golang",
      pull: "always",
      environment: {
        CGO_ENABLED: "0",
        GO111MODULE: "on",
      },
      commands: [
        "go build -v -ldflags \"-X main.build=${DRONE_BUILD_NUMBER}\" -a -o release/" + os + "/" + arch + "/drone-discord",
      ],
      when: {
        event: [ "push", "pull_request" ],
      },
    },
    {
      name: "build-tag",
      image: "golang",
      pull: "always",
      environment: {
        CGO_ENABLED: "0",
        GO111MODULE: "on",
      },
      commands: [
        "go build -v -ldflags \"-X main.version=${DRONE_TAG##v} -X main.build=${DRONE_BUILD_NUMBER}\" -a -o release/" + os + "/" + arch + "/drone-discord",
      ],
      when: {
        event: [ "tag" ],
      },
    },
    {
      name: "executable",
      image: "golang",
      pull: "always",
      commands: [
        "./release/" + os + "/" + arch + "/drone-discord –help",
      ],
    },
    {
      name: "dryrun",
      image: "plugins/docker:" + os + "-" + arch,
      pull: "always",
      settings: {
        dry_run: true,
        tags: os + "-" + arch,
        dockerfile: "docker/Dockerfile." + os + "." + arch,
        repo: "appleboy/drone-discord",
        username: { "from_secret": "docker_username" },
        password: { "from_secret": "docker_password" },
      },
      when: {
        event: [ "pull_request" ],
      },
    },
    {
      name: "publish",
      image: "plugins/docker:" + os + "-" + arch,
      pull: "always",
      settings: {
        auto_tag: true,
        auto_tag_suffix: os + "-" + arch,
        dockerfile: "docker/Dockerfile." + os + "." + arch,
        repo: "appleboy/drone-discord",
        username: { "from_secret": "docker_username" },
        password: { "from_secret": "docker_password" },
      },
      when: {
        event: [ "push", "tag" ],
      },
    },
  ],
  depends_on: [
    "testing",
  ],
  trigger: {
    branch: [ "master" ],
  },
};
local PipelineNotifications = {
  kind: "pipeline",
  name: "notifications",
  platform: {
    os: "linux",
    arch: "amd64",
  },
  clone: {
    disable: true,
  },
  steps: [
    {
      name: "microbadger",
      image: "plugins/webhook:1",
      pull: "always",
      settings: {
        url: { "from_secret": "microbadger_url" },
      },
    },
  ],
  depends_on: [
    "linux-amd64",
    "linux-arm64",
    "linux-arm",
  ],
  trigger: {
    branch: [ "master" ],
    event: [ "push", "tag" ],
  },
};
[
  PipelineTesting,
  PipelineBuild("linux", "amd64"),
  PipelineBuild("linux", "arm64"),
  PipelineBuild("linux", "arm"),
  PipelineNotifications,
]
