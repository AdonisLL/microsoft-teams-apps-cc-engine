using System;
using System.Collections.Generic;
using System.Text;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models
{
    public class DataQueueMessageOptions
    {
        /// <summary>
        /// Gets or sets the value for the delay to be applied to the data queue message
        /// used to force mark a notification as complete if it is not already
        /// complete to ensure it is not left in a "sending" state.
        /// </summary>
        public double ForceCompleteMessageDelayInSeconds { get; set; }
    }
}
