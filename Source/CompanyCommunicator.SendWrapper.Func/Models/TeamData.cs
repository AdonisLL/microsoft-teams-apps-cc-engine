using System;
using System.Collections.Generic;
using System.Text;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models
{
    public class TeamData
    {
        /// <summary>
        /// Gets or sets the team id value.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the team id value.
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the delivery status value.
        /// </summary>
        public string DeliveryStatus { get; set; }

        /// <summary>
        /// Gets or sets the status reason value.
        /// </summary>
        public string StatusReason { get; set; }

        /// <summary>
        /// Gets or sets the error message.
        /// </summary>
        public string Error { get; set; }
    }
}
