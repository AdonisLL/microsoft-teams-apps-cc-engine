﻿// <copyright file="GraphPermissionType.cs" company="Microsoft">
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// </copyright>

namespace Microsoft.Teams.Apps.CompanyCommunicator.Common.Services.MicrosoftGraph
{
    /// <summary>
    /// Graph Permission Type.
    /// </summary>
    public enum GraphPermissionType
    {
        /// <summary>
        /// This represents application permission of Microsoft Graph.
        /// </summary>
        Application,

        /// <summary>
        /// This represents delgeate permission of Microsoft Graph.
        /// </summary>
        Delegate,
    }
}
