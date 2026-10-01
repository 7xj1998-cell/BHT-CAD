using System;
namespace BHT.Core
{
    // Completion callbacks may dispatch another CAD operation; wait until commands end.
    public sealed class CommandCompletionGate
    {
        private Action callback;
        public CommandCompletionGate(Action callback) { this.callback = callback; }
        public bool TryFinish(string activeCommands)
        {
            if (!string.IsNullOrEmpty(activeCommands)) return false;
            var next = callback; callback = null;
            if (next != null) next();
            return true;
        }
    }
}
