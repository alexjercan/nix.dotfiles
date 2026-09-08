{config, ...}: {
  programs.scufris = {
    enable = true;

    agent.piPackage = config.programs.agents.pi.finalPackage;
    aiToolsApi = {
      enable = false;
      baseUrl = "http://127.0.0.1:10300";
    };

    service = {
      enable = true;
      remoteSurface = {
        enable = true;
        port = 10440;
        tokenFile = "${config.xdg.dataHome}/scufris/credentials/ios/surface-token";
      };
    };

    desktop = {
      enable = true;
      speech.enable = true;
    };

    agent.briefing = {
      profiles.morning.schedule = "08:00";

      # The night reviews the day's commits and fixes what it finds, so it is
      # nothing like a morning of reports: it needs hours, it comes back with a
      # list rather than a headline, and two of these at once is already wide
      # because each one fans out into review lanes.
      profiles.nightly = {
        schedule = "23:00";
        deadline = 28800;
        sourceDeadline = 28800;
        parallel = 2;
        maxOffers = 8;
        maxBody = 65536;
      };

      sources.morning.jobs = {
        description = "What Scufris did overnight.";
        keywords = {
          harness = "pi";
          model = "openai-codex/gpt-5.6-sol";
          thinking = "medium";
        };
        guidance = ''
          Report what Scufris did since the moment named above. Read only;
          change nothing, and start no job.

          - Run `scufris-jobs history --since <that moment> --json`. It lists
            archived jobs as well as live ones, so it is the only listing that
            can answer what landed. With no previous run named, drop `--since`
            and report the whole listing.
          - Put the jobs in a Markdown table: job ID, project, workspace,
            state, and what the receipt says. One row for each job, newest
            last.

          The receipt is measured and you are not. Quote its fields verbatim
          and do not judge whether any work is done:

          - Copy each string in `receipt.sentences` into the row exactly as it
            is written. Say "not landed" in those words, and say "claimed, not
            verified" in those words.
          - A `facts` value of `false` was measured and is false. A value of
            `null` was not measured; say it is unknown and give the reason from
            `unavailable`. Never report an unmeasured fact as a no.
          - A job with no receipt has none. Say so rather than inferring one
            from its state or summary.

          Facts are counts: jobs in the window, jobs that landed, jobs with an
          unverified claim. Set `status` to `attention` when any receipt
          carries a sentence, because an unverified claim is the owner's to
          settle. A window with no job at all is `status = "ok"` and one short
          line.
        '';
      };
    };
  };
}
