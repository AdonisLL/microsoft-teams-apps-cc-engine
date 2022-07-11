using System;
using System.Collections.Generic;
using System.Text;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models
{
    public class OrchestrationStatusResponse
    {
        /// <summary>
        /// Gets or sets the orchestration name.
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the Instance id of the orchestration.
        /// </summary>
        public string InstanceId { get; set; }

        /// <summary>
        /// Gets or sets the runtime status of the orchestration.
        /// </summary>
        public string RuntimeStatus { get; set; }
    }
}
