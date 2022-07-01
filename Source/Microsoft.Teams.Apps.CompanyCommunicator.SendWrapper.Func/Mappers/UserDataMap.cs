using System;
using CsvHelper.Configuration;
using Microsoft.Extensions.Localization;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Resources;
using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Mappers
{
    public sealed class UserDataMap : ClassMap<UserData>
    {
        private readonly IStringLocalizer<Strings> localizer;

        /// <summary>
        /// Initializes a new instance of the <see cref="UserDataMap"/> class.
        /// </summary>
        /// <param name="localizer">Localization service.</param>
        public UserDataMap(IStringLocalizer<Strings> localizer)
        {
            this.localizer = localizer ?? throw new ArgumentNullException(nameof(localizer));
            this.Map(x => x.Id).Name(this.localizer.GetString("ColumnName_UserId"));
            this.Map(x => x.Upn).Name(this.localizer.GetString("ColumnName_Upn"));
            this.Map(x => x.Name).Name(this.localizer.GetString("ColumnName_UserName"));
            this.Map(x => x.UserType).Name(this.localizer.GetString("ColumnName_UserType"));
            this.Map(x => x.DeliveryStatus).Name(this.localizer.GetString("ColumnName_DeliveryStatus"));
            this.Map(x => x.StatusReason).Name(this.localizer.GetString("ColumnName_StatusReason"));
            this.Map(x => x.Error).Name(this.localizer.GetString("ColumnName_Error"));
        }
    }
}
