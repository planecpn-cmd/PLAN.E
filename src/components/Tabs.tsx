import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ViewStyle } from 'react-native';
import { colors, radii, spacing, touchTarget } from '@/theme/tokens';
import { typography } from '@/theme/typography';

interface TabItem {
  id: string;
  label: string;
}

interface TabsProps {
  tabs: TabItem[];
  activeTabId: string;
  onSelectTab: (id: string) => void;
  style?: ViewStyle;
}

export function Tabs({ tabs, activeTabId, onSelectTab, style }: TabsProps) {
  return (
    <View style={[styles.container, style]}>
      {tabs.map((tab) => {
        const isActive = tab.id === activeTabId;
        return (
          <TouchableOpacity
            key={tab.id}
            style={[styles.tab, isActive && styles.activeTab]}
            onPress={() => onSelectTab(tab.id)}
          >
            <Text style={[typography.styles.bodyMedium, isActive ? styles.activeText : styles.inactiveText]}>
              {tab.label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    backgroundColor: colors.sage,
    borderRadius: radii.pill,
    padding: spacing.xs,
  },
  tab: {
    flex: 1,
    minHeight: touchTarget.minHeight - 8,
    borderRadius: radii.pill,
    justifyContent: 'center',
    alignItems: 'center',
  },
  activeTab: {
    backgroundColor: colors.forest,
  },
  activeText: {
    color: colors.white,
    fontWeight: 'bold',
  },
  inactiveText: {
    color: colors.ink,
    fontWeight: '500',
  },
});
