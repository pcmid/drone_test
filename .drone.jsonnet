local PipelineTesting = {
  kind: 'pipeline',
  type: 'kubernetes',
  name: 'testing',
  platform: {
    os: 'linux',
    arch: 'amd64',
  },
  steps: [
    {
      name: 'test',
      image: 'golang',
      pull: 'always',
      environment: {
        GO111MODULE: 'on',
      },
      commands: [
        'go test',
      ],
    },
  ],
  trigger: {
    branch: ['master'],
  },
};
local PipelineBuild(os='linux', arch='amd64') = {
  kind: 'pipeline',
  type: 'kubernetes',
  name: os + '-' + arch,
  strigger: {
    branch: ['master'],
  },
  steps: [
    {
      name: 'build-push',
      image: 'golang',
      pull: 'always',
      environment: {
        CGO_ENABLED: '0',
        GO111MODULE: 'on',
      },
      commands: [
        'GOOS=' + os + ' ' + 'GOARCH=' + arch + ' ' +
        'go build -v -ldflags "-X main.version=${DRONE_COMMIT_SHA:0:8} -X main.build=${DRONE_BUILD_NUMBER}" -a -o build/${DRONE_REPO_NAME}_' + os + '_' + arch,
      ],
      when: {
        event: {
          exclude: ['tag'],
        },
      },
    },
    {
      name: 'build',
      image: 'golang',
      pull: 'always',
      environment: {
        GO111MODULE: 'on',
      },
      commands: [
        'GOOS=' + os + ' ' + 'GOARCH=' + arch + ' ' +
        'go build -v -ldflags "-X main.version=${DRONE_TAG##v} -X main.build=${DRONE_BUILD_NUMBER}" -a -o release/${DRONE_REPO_NAME}_' + os + '_' + arch,
      ],
      when: {
        event: ['tag'],
      },
    },
    {
      name: 'release',
      image: 'plugins/github-release',
      settings: {
        api_key: { from_secret: 'GITHUB_API_TOKEN' },
        files: 'release/*',
      },
      when: {
        event: 'tag',
      },
    },
    {
      name: 'publish',
      image: 'plugins/docker:' + os + '-' + arch,
      pull: 'always',
      settings: {
        auto_tag: true,
        auto_tag_suffix: os + '-' + arch,
        dockerfile: 'docker/Dockerfile.' + os + '.' + arch,
        repo: '${DRONE_REPO}',
        username: { from_secret: 'DOCKER_USERNAME' },
        password: { from_secret: 'DOCKER_PASSWORD' },
      },
      when: {
        event: ['tag'],
      },
    },
  ],
  depends_on: [
    'testing',
  ],
  trigger: {
    branch: ['master'],
  },
};
[
  PipelineTesting,
  PipelineBuild('linux', 'amd64'),
  PipelineBuild('linux', 'arm64'),
  PipelineBuild('linux', 'arm'),
]
