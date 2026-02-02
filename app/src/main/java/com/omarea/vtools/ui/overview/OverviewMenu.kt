package com.omarea.vtools.ui.overview

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.omarea.vtools.R
import top.yukonga.miuix.kmp.basic.Card
import top.yukonga.miuix.kmp.basic.CardDefaults
import top.yukonga.miuix.kmp.theme.MiuixTheme

data class OverviewNavItem(
    val id: Int,
    val titleRes: Int,
    val iconRes: Int,
    val requiresRoot: Boolean
)

data class OverviewSection(
    val titleRes: Int,
    val items: List<OverviewNavItem>
)

@Composable
fun OverviewMenu(
    isRootAvailable: Boolean,
    onItemClick: (Int) -> Unit
) {
    val sections = listOf(
        OverviewSection(
            titleRes = R.string.menu_section_performance,
            items = listOf(
                OverviewNavItem(R.id.nav_core_control, R.string.menu_core_control, R.drawable.ic_menu_cpu, true),
                OverviewNavItem(R.id.nav_swap, R.string.menu_swap, R.drawable.ic_menu_swap, true),
                OverviewNavItem(R.id.nav_processes, R.string.menu_processes, R.drawable.ic_processes, true),
                OverviewNavItem(R.id.nav_fps_chart, R.string.menu_fps_chart, R.drawable.fw_float_fps, true)
            )
        ),
        OverviewSection(
            titleRes = R.string.menu_section_power,
            items = listOf(
                OverviewNavItem(R.id.nav_charge, R.string.menu_charge, R.drawable.battery, false),
                OverviewNavItem(R.id.nav_power_utilization, R.string.menu_power_utilization, R.drawable.ic_bat_stats, false)
            )
        ),
        OverviewSection(
            titleRes = R.string.menu_section_advanced,
            items = listOf(
                OverviewNavItem(R.id.nav_applictions, R.string.menu_applictions, R.drawable.ic_menu_modules, true),
                OverviewNavItem(R.id.nav_img, R.string.menu_img, R.drawable.ic_menu_img, true),
                OverviewNavItem(R.id.nav_additional, R.string.menu_sundry, R.drawable.ic_menu_vboot, true),
                OverviewNavItem(R.id.nav_additional_all, R.string.menu_additional, R.drawable.ic_menu_shell, true),
                OverviewNavItem(R.id.nav_app_magisk, R.string.menu_app_magisk, R.drawable.ic_menu_addon, true),
                OverviewNavItem(R.id.nav_miui_thermal, R.string.menu_miui_thermal, R.drawable.ic_menu_hot, false),
                OverviewNavItem(R.id.nav_modules, R.string.menu_modules, R.drawable.ic_menu_magisk, true)
            )
        )
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 8.dp, vertical = 8.dp)
    ) {
        sections.forEach { section ->
            Text(
                text = stringResource(section.titleRes),
                style = MiuixTheme.textStyles.footnote1,
                color = MiuixTheme.colorScheme.onSurfaceContainerVariant
            )
            Spacer(modifier = Modifier.height(10.dp))
            section.items.chunked(2).forEach { rowItems ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    rowItems.forEach { item ->
                        OverviewMenuItem(
                            item = item,
                            enabled = isRootAvailable || !item.requiresRoot,
                            onClick = onItemClick,
                            modifier = Modifier.weight(1f)
                        )
                    }
                    if (rowItems.size == 1) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
            }
            Spacer(modifier = Modifier.height(6.dp))
        }
    }
}

@Composable
private fun OverviewMenuItem(
    item: OverviewNavItem,
    enabled: Boolean,
    onClick: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    val alpha = if (enabled) 1f else 0.4f
    Card(
        modifier = modifier
            .heightIn(min = 64.dp)
            .alpha(alpha)
            .clickable(enabled = enabled) { onClick(item.id) },
        cornerRadius = 16.dp,
        insideMargin = androidx.compose.foundation.layout.PaddingValues(8.dp),
        colors = CardDefaults.defaultColors()
    ) {
        Row(
            modifier = Modifier
                .heightIn(min = 68.dp)
                .padding(horizontal = 8.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                painter = painterResource(item.iconRes),
                contentDescription = null,
                tint = MiuixTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(10.dp))
            Text(
                text = stringResource(item.titleRes),
                style = MiuixTheme.textStyles.body1,
                color = MiuixTheme.colorScheme.onSurface
            )
        }
    }
}
