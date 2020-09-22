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
        "go test",
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
  strigger: {
    branch: [ "master" ],
  },
  steps: [
    {
      name: "build",
      image: "golang",
      pull: "always",
      environment: {
        GO111MODULE: "on",
      },
      commands: [
        "GOOS=" + os + " " + "GOARCH=" + arch + " " + "go build -v -ldflags \"-X main.version=${DRONE_TAG##v} -X main.build=${DRONE_BUILD_NUMBER}\" -a -o release/" + os + "/" + arch + "/drone-discord",
      ],
      when: {
        event: [ "push", "pull_request", "tag" ],
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
        event: [ "tag" ],
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
[
  PipelineTesting,
  PipelineBuild("linux", "amd64"),
  PipelineBuild("linux", "arm64"),
  PipelineBuild("linux", "arm"),
]
