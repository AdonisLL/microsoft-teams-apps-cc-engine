using System;
using System.Collections.Generic;
using System.Text;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models
{
    public class UserData
    {
        /// <summary>
        /// Gets or sets the user id.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the user principal name.
        /// </summary>
        public string Upn { get; set; }

        /// <summary>
        /// Gets or sets the display name.
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the user type.
        /// </summary>
        public string UserType { get; set; }

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
