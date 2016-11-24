using System;
using System.IO;
using System.Linq;
using LibGit2Sharp;

namespace GitStatus
{
    internal class Program
    {
        private static string FindGitDir(DirectoryInfo startDirectory)
        {
            while (true)
            {
                var gitDir = startDirectory.GetDirectories().FirstOrDefault(di => di.Name == ".git");

                if (gitDir != null)
                {
                    return gitDir.FullName;
                }

                if (startDirectory.Parent == null || startDirectory == startDirectory.Parent)
                {
                    return null;
                }

                startDirectory = startDirectory.Parent;
            }
        }

        public static void Main(string[] args)
        {
            try
            {
                var repositoryDirectory = FindGitDir(new DirectoryInfo("."));
                if (repositoryDirectory == null || !Directory.Exists(repositoryDirectory))
                {
                    Console.WriteLine("fatal: Not a git repository (or any of the parent directories): .git");
                    return;
                }

                var repo = new Repository(repositoryDirectory);
                var status = repo.RetrieveStatus();
                var branch = repo.Head.FriendlyName;

                var remote = repo.Head.IsTracking
                    ? "."
                    : "_NO_REMOTE_TRACKING_";

                if (repo.Head.IsTracking)
                {
                    var ahead = repo.Head.TrackingDetails.AheadBy.HasValue && repo.Head.TrackingDetails.AheadBy.Value > 0
                        ? "_AHEAD_" + repo.Head.TrackingDetails.AheadBy.Value
                        : string.Empty;

                    var behind = repo.Head.TrackingDetails.BehindBy.HasValue && repo.Head.TrackingDetails.BehindBy.Value > 0
                        ? "_BEHIND_" + repo.Head.TrackingDetails.BehindBy.Value
                        : string.Empty;

                    if (!string.IsNullOrEmpty(ahead) || !string.IsNullOrEmpty(behind))
                    {
                        remote = behind + ahead;
                    }
                }

                var upstream = repo.Head.IsTracking
                    ? repo.Head.TrackedBranch.FriendlyName
                    : "^";

                var staged = status.Staged.Count();
                var conflicts = repo.Index.Conflicts.Count();
                var changed = status.Modified.Count();
                var untracked = status.Untracked.Count();
                var stashed = repo.Stashes.Count();
                var isClean = status.IsDirty ? 0 : 1;

                Console.WriteLine(
                    "{0}\n{1}\n{2}\n{3}\n{4}\n{5}\n{6}\n{7}\n{8}\n",
                    branch,
                    remote,
                    upstream,
                    staged,
                    conflicts,
                    changed,
                    untracked,
                    stashed,
                    isClean
                );

            }
            catch
            {
                Console.WriteLine("fatal: Not a git repository (or any of the parent directories): .git");
            }
        }
    }
}